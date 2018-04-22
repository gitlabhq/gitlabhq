module EE
  module AuthHelper
    extend ::Gitlab::Utils::Override

    override :form_based_provider?
    def form_based_provider?(name)
      super || name.to_s == 'kerberos'
    end
  end
end
