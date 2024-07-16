# frozen_string_literal: true

module Ci
  module PipelineSchedules
    class BaseSaveService
      include Gitlab::Utils::StrongMemoize

      # The only way that ref can be unexpanded after #expand_short_ref runs is if the ref
      # is ambiguous because both a branch and a tag with the name exist, or it is
      # ambiguous because neither exists.
      INVALID_REF_MESSAGE = 'Ref is ambiguous'
      INVALID_REF_MODEL_MESSAGE = 'is ambiguous'

      def execute
        schedule.assign_attributes(params)

        return forbidden_to_save unless allowed_to_save?
        return forbidden_to_save_variables unless allowed_to_save_variables?

        # This validation cannot be added to the model yet due to operation hooks
        # causing incidents
        unless valid_ref_format?
          schedule.expand_short_ref

          # Only return an error if the ref fails to expand
          return invalid_ref_format unless valid_ref_format?
        end

        if schedule.save
          ServiceResponse.success(payload: schedule)
        else
          ServiceResponse.error(payload: schedule, message: schedule.errors.full_messages)
        end
      end

      private

      attr_reader :project, :user, :params, :schedule

      def valid_ref_format?
        schedule.ref.present? && Ci::PipelineSchedule::VALID_REF_FORMAT_REGEX.match?(schedule.ref)
      end

      def allowed_to_save?
        # Disable cache because the same ability may already have been checked
        # for the same records with different attributes. For example, we do not
        # want an unauthorized user to change an unprotected ref to a protected
        # ref.
        user.can?(self.class::AUTHORIZE, schedule, cache: false)
      end

      def forbidden_to_save
        # We add the error to the base object too
        # because model errors are used in the API responses and the `form_errors` helper.
        schedule.errors.add(:base, authorize_message)

        ServiceResponse.error(payload: schedule, message: [authorize_message], reason: :forbidden)
      end

      def allowed_to_save_variables?
        return true if params[:variables_attributes].blank?

        user.can?(:set_pipeline_variables, project)
      end

      def forbidden_to_save_variables
        message = _('The current user is not authorized to set pipeline schedule variables')

        # We add the error to the base object too
        # because model errors are used in the API responses and the `form_errors` helper.
        schedule.errors.add(:base, message)

        ServiceResponse.error(payload: schedule, message: [message], reason: :forbidden)
      end

      def invalid_ref_format
        schedule.errors.add(:ref, INVALID_REF_MODEL_MESSAGE)

        ServiceResponse.error(payload: schedule, message: [INVALID_REF_MESSAGE])
      end
    end
  end
end
