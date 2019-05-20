# frozen_string_literal: true

module Members
  class CreateService < Members::BaseService
    DEFAULT_LIMIT = 100

    def execute(source)
      return error(s_('AddMember|No users specified.')) if params[:user_ids].blank?

      user_ids = params[:user_ids].split(',').uniq

      return error(s_("AddMember|Too many users specified (limit is %{user_limit})") % { user_limit: user_limit }) if
        user_limit && user_ids.size > user_limit

      members = source.add_users(
        user_ids,
        params[:access_level],
        expires_at: params[:expires_at],
        current_user: current_user
      )

      errors = []

      members.each do |member|
        if member.errors.any?
          current_error =
            # Invited users may not have an associated user
            if member.user.present?
              "#{member.user.username}: "
            else
              ""
            end

          current_error += member.errors.full_messages.to_sentence
          errors << current_error
        else
          after_execute(member: member)
        end
      end

      return success unless errors.any?

      error(errors.to_sentence)
    end

    private

    def user_limit
      limit = params.fetch(:limit, DEFAULT_LIMIT)

      limit && limit < 0 ? nil : limit
    end
  end
end
