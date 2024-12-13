# frozen_string_literal: true

# This is based on https://github.com/rmosolgo/graphql-ruby/blob/v1.11.8/lib/graphql/subscriptions/action_cable_subscriptions.rb#L19-L82
# modified to work with our own ActionCableLink client

class GraphqlChannel < ApplicationCable::Channel # rubocop:disable Gitlab/NamespacedClass
  def subscribed
    @subscription_ids = []

    query = params['query']
    variables = Gitlab::Graphql::Variables.new(params['variables']).to_h
    operation_name = params['operationName']

    result = GitlabSchema.execute(
      query,
      context: context,
      variables: variables,
      operation_name: operation_name
    )

    payload = {
      result: result.to_h,
      more: result.subscription?
    }

    # Track the subscription here so we can remove it
    # on unsubscribe.
    @subscription_ids << result.context[:subscription_id] if result.context[:subscription_id]

    transmit(payload)
  end

  def unsubscribed
    return if @subscription_ids.blank?

    @subscription_ids.each do |sid|
      GitlabSchema.subscriptions.delete_subscription(sid)
    end
  end

  rescue_from Gitlab::Graphql::Variables::Invalid do |exception|
    transmit({ errors: [{ message: exception.message }] })
  end

  private

  # When modifying the context, also update GraphqlController#context if needed
  # so that we have similar context when executing queries, mutations, and subscriptions
  #
  # Objects added to the context may also need to be reloaded in
  # `Subscriptions::BaseSubscription` so that they are not stale
  def context
    request_authenticator = Gitlab::Auth::RequestAuthenticator.new(request)
    scope_validator = ::Gitlab::Auth::ScopeValidator.new(current_user, request_authenticator)
    { channel: self, current_user: current_user, is_sessionless_user: false, scope_validator: scope_validator }
  end
end

::GraphqlChannel.prepend_mod_with('GraphqlChannel')
