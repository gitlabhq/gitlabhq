# frozen_string_literal: true

require 'zlib'

# Controller concern that checks if an `experimentation_subject_id cookie` is present and sets it if absent.
# Used for A/B testing of experimental features. Exposes the `experiment_enabled?(experiment_name)` method
# to controllers and views. It returns true when the experiment is enabled and the user is selected as part
# of the experimental group.
#
module Gitlab
  module Experimentation
    module ControllerConcern
      include ::Gitlab::Experimentation::GroupTypes
      extend ActiveSupport::Concern

      included do
        before_action :set_experimentation_subject_id_cookie, unless: :dnt_enabled?
        helper_method :experiment_enabled?, :experiment_tracking_category_and_group
      end

      def set_experimentation_subject_id_cookie
        return if cookies[:experimentation_subject_id].present?

        cookies.permanent.signed[:experimentation_subject_id] = {
          value: SecureRandom.uuid,
          secure: ::Gitlab.config.gitlab.https,
          httponly: true
        }
      end

      def push_frontend_experiment(experiment_key)
        var_name = experiment_key.to_s.camelize(:lower)
        enabled = experiment_enabled?(experiment_key)

        gon.push({ experiments: { var_name => enabled } }, true)
      end

      def experiment_enabled?(experiment_key)
        return false if dnt_enabled?

        return true if Experimentation.enabled_for_value?(experiment_key, experimentation_subject_index(experiment_key))
        return true if forced_enabled?(experiment_key)

        false
      end

      def track_experiment_event(experiment_key, action, value = nil)
        return if dnt_enabled?

        track_experiment_event_for(experiment_key, action, value) do |tracking_data|
          ::Gitlab::Tracking.event(tracking_data.delete(:category), tracking_data.delete(:action), **tracking_data)
        end
      end

      def frontend_experimentation_tracking_data(experiment_key, action, value = nil)
        return if dnt_enabled?

        track_experiment_event_for(experiment_key, action, value) do |tracking_data|
          gon.push(tracking_data: tracking_data)
        end
      end

      def record_experiment_user(experiment_key)
        return if dnt_enabled?
        return unless Experimentation.enabled?(experiment_key) && current_user

        ::Experiment.add_user(experiment_key, tracking_group(experiment_key), current_user)
      end

      def record_experiment_conversion_event(experiment_key)
        return if dnt_enabled?
        return unless current_user
        return unless Experimentation.enabled?(experiment_key)

        ::Experiment.record_conversion_event(experiment_key, current_user)
      end

      def experiment_tracking_category_and_group(experiment_key)
        "#{tracking_category(experiment_key)}:#{tracking_group(experiment_key, '_group')}"
      end

      private

      def dnt_enabled?
        Gitlab::Utils.to_boolean(request.headers['DNT'])
      end

      def experimentation_subject_id
        cookies.signed[:experimentation_subject_id]
      end

      def experimentation_subject_index(experiment_key)
        return if experimentation_subject_id.blank?

        if Experimentation.experiment(experiment_key).use_backwards_compatible_subject_index
          experimentation_subject_id.delete('-').hex % 100
        else
          Zlib.crc32("#{experiment_key}#{experimentation_subject_id}") % 100
        end
      end

      def track_experiment_event_for(experiment_key, action, value)
        return unless Experimentation.enabled?(experiment_key)

        yield experimentation_tracking_data(experiment_key, action, value)
      end

      def experimentation_tracking_data(experiment_key, action, value)
        {
          category: tracking_category(experiment_key),
          action: action,
          property: tracking_group(experiment_key, "_group"),
          label: experimentation_subject_id,
          value: value
        }.compact
      end

      def tracking_category(experiment_key)
        Experimentation.experiment(experiment_key).tracking_category
      end

      def tracking_group(experiment_key, suffix = nil)
        return unless Experimentation.enabled?(experiment_key)

        group = experiment_enabled?(experiment_key) ? GROUP_EXPERIMENTAL : GROUP_CONTROL

        suffix ? "#{group}#{suffix}" : group
      end

      def forced_enabled?(experiment_key)
        params.has_key?(:force_experiment) && params[:force_experiment] == experiment_key.to_s
      end
    end
  end
end
