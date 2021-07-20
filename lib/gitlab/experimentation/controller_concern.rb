# frozen_string_literal: true

require 'zlib'

# Controller concern that checks if an `experimentation_subject_id cookie` is present and sets it if absent.
# Used for A/B testing of experimental features. Exposes the `experiment_enabled?(experiment_name, subject: nil)` method
# to controllers and views. It returns true when the experiment is enabled and the user is selected as part
# of the experimental group.
#
module Gitlab
  module Experimentation
    module ControllerConcern
      include ::Gitlab::Experimentation::GroupTypes
      include Gitlab::Tracking::Helpers
      extend ActiveSupport::Concern

      included do
        before_action :set_experimentation_subject_id_cookie, unless: :dnt_enabled?
        helper_method :experiment_enabled?, :experiment_tracking_category_and_group, :record_experiment_group, :tracking_label
      end

      def set_experimentation_subject_id_cookie
        if Gitlab.dev_env_or_com?
          return if cookies[:experimentation_subject_id].present?

          cookies.permanent.signed[:experimentation_subject_id] = {
            value: SecureRandom.uuid,
            secure: ::Gitlab.config.gitlab.https,
            httponly: true
          }
        else
          # We set the cookie before, although experiments are not conducted on self managed instances.
          cookies.delete(:experimentation_subject_id)
        end
      end

      def push_frontend_experiment(experiment_key, subject: nil)
        var_name = experiment_key.to_s.camelize(:lower)

        enabled = experiment_enabled?(experiment_key, subject: subject)

        gon.push({ experiments: { var_name => enabled } }, true)
      end

      def experiment_enabled?(experiment_key, subject: nil)
        return true if forced_enabled?(experiment_key)
        return false if dnt_enabled?

        Experimentation.log_invalid_rollout(experiment_key, subject)

        subject ||= fallback_experimentation_subject_index(experiment_key)

        Experimentation.in_experiment_group?(experiment_key, subject: subject)
      end

      def track_experiment_event(experiment_key, action, value = nil, subject: nil)
        return if dnt_enabled?

        track_experiment_event_for(experiment_key, action, value, subject: subject) do |tracking_data|
          ::Gitlab::Tracking.event(tracking_data.delete(:category), tracking_data.delete(:action), **tracking_data.merge!(user: current_user))
        end
      end

      def frontend_experimentation_tracking_data(experiment_key, action, value = nil, subject: nil)
        return if dnt_enabled?

        track_experiment_event_for(experiment_key, action, value, subject: subject) do |tracking_data|
          gon.push(tracking_data: tracking_data)
        end
      end

      def record_experiment_user(experiment_key, context = {})
        return if dnt_enabled?
        return unless Experimentation.active?(experiment_key) && current_user

        subject = Experimentation.rollout_strategy(experiment_key) == :cookie ? nil : current_user

        ::Experiment.add_user(experiment_key, tracking_group(experiment_key, nil, subject: subject), current_user, context)
      end

      def record_experiment_group(experiment_key, group)
        return if dnt_enabled?
        return unless Experimentation.active?(experiment_key) && group

        variant_subject = Experimentation.rollout_strategy(experiment_key) == :cookie ? nil : group
        variant = tracking_group(experiment_key, nil, subject: variant_subject)

        ::Experiment.add_group(experiment_key, group: group, variant: variant)
      end

      def record_experiment_conversion_event(experiment_key, context = {})
        return if dnt_enabled?
        return unless current_user
        return unless Experimentation.active?(experiment_key)

        ::Experiment.record_conversion_event(experiment_key, current_user, context)
      end

      def experiment_tracking_category_and_group(experiment_key, subject: nil)
        "#{tracking_category(experiment_key)}:#{tracking_group(experiment_key, '_group', subject: subject)}"
      end

      private

      def experimentation_subject_id
        cookies.signed[:experimentation_subject_id]
      end

      def fallback_experimentation_subject_index(experiment_key)
        return if experimentation_subject_id.blank?

        if Experimentation.get_experiment(experiment_key).use_backwards_compatible_subject_index
          experimentation_subject_id.delete('-')
        else
          experimentation_subject_id
        end
      end

      def track_experiment_event_for(experiment_key, action, value, subject: nil)
        return unless Experimentation.active?(experiment_key)

        yield experimentation_tracking_data(experiment_key, action, value, subject: subject)
      end

      def experimentation_tracking_data(experiment_key, action, value, subject: nil)
        {
          category: tracking_category(experiment_key),
          action: action,
          property: tracking_group(experiment_key, "_group", subject: subject),
          label: tracking_label(subject),
          value: value
        }.compact
      end

      def tracking_category(experiment_key)
        Experimentation.get_experiment(experiment_key).tracking_category
      end

      def tracking_group(experiment_key, suffix = nil, subject: nil)
        return unless Experimentation.active?(experiment_key)

        subject ||= fallback_experimentation_subject_index(experiment_key)
        group = experiment_enabled?(experiment_key, subject: subject) ? GROUP_EXPERIMENTAL : GROUP_CONTROL

        suffix ? "#{group}#{suffix}" : group
      end

      def forced_enabled?(experiment_key)
        return true if params.has_key?(:force_experiment) && params[:force_experiment] == experiment_key.to_s
        return false if cookies[:force_experiment].blank?

        cookies[:force_experiment].to_s.split(',').any? { |experiment| experiment.strip == experiment_key.to_s }
      end

      def tracking_label(subject = nil)
        return experimentation_subject_id if subject.blank?

        if subject.respond_to?(:to_global_id)
          Digest::MD5.hexdigest(subject.to_global_id.to_s)
        else
          Digest::MD5.hexdigest(subject.to_s)
        end
      end
    end
  end
end
