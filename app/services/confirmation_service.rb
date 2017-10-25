# Users and Emails can contain unconfirmed duplicates.  When one is confirmed,
# remove any duplicates (don't remove duplicate User emails, just leave unconfirmed)
class ConfirmationService

  def initialize(resource_class, confirmation_token)
    @resource_class, @confirmation_token = resource_class, confirmation_token
  end

  def execute
    resource = @resource_class.find_first_by_auth_conditions(confirmation_token: @confirmation_token)
    if resource
      email = resource.email

      # verify email being confirmed is not already confirmed elsewhere
      unless Email.confirmed.exists?(email: email) || User.confirmed.exists?(email: email)
        resource = @resource_class.confirm_by_token(@confirmation_token)
        if resource.errors.empty?
          # remove any duplicate emails from the emails table
          Email.unconfirmed.where(email: email).each do |email|
            email.destroy
          end

          # nothing to do about the duplicate user emails, just leave unconfirmed
        end
      else
        resource.errors.add(:base, 'This email address was confirmed by someone else')
      end
    end
    resource
  end
end
