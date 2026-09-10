# frozen_string_literal: true

module Mcp
  module Tools
    module Users
      class GetUserTool < Mcp::Tools::Base::GraphqlTool
        register_version VERSIONS[:v0_1_0], {
          graphql_operation: load_graphql('users/get_user.query.graphql')
        }

        def build_variables
          validate_identifiers!

          {
            username: params[:username],
            id: params[:id] && ::Gitlab::GlobalId.as_global_id(params[:id], model_name: 'User').to_s,
            me: (true if params[:me])
          }.compact
        end

        def operation_name
          params[:me] ? 'currentUser' : 'user'
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        # Enforced in Ruby instead of a schema oneOf: a root-level oneOf would stop
        # SchemaDefaults from applying additionalProperties: false to the schema.
        # me counts only when true: an explicit false behaves like an omitted key,
        # matching how the base service treats null and empty-string arguments.
        def validate_identifiers!
          provided = [params.key?(:username), params.key?(:id), params[:me] == true].count(true)

          raise ArgumentError, 'Provide exactly one of username, id, or me' unless provided == 1
        end

        def process_result(result)
          return user_not_found_error if resource_not_found?(result)

          processed_result = super
          return processed_result if processed_result[:isError]

          user = format_user(processed_result[:structuredContent])
          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(user) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, user)
        end

        def format_user(data)
          {
            id: ::GlobalID.parse(data['id']).model_id.to_i,
            username: data['username'],
            name: data['name'],
            state: data['state'],
            web_url: data['webUrl']
          }
        end

        def user_not_found_error
          ::Mcp::Tools::Base::Response.error('User not found or inaccessible')
        end
      end
    end
  end
end
