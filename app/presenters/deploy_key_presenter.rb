# frozen_string_literal: true

class DeployKeyPresenter < KeyPresenter # rubocop:disable Gitlab/NamespacedClass
  presents ::DeployKey, as: :deploy_key

  def humanized_error_message
    super(type: :deploy_key)
  end
end
