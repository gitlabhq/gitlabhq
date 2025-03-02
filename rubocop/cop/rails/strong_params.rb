# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Cop that detects passing params as an argument without making them
      # StrongParams first. Used to reduce the likelihood of input
      # validation errors outside of ActiveModel. E.g. when a parameter
      # is an array of strings instead of a single string, and that gets
      # passed to a Service or Helper method.
      #
      # This cop has an "unsafe" AutoCorrect for simple key access. It is
      # unsafe in that "it produces code that's mostly equivalent to the
      # original code, but not 100% equivalent".
      # In all other cases a manual correction is required.
      #
      # @example
      #   # bad - find_by will check an array of values until one returns
      #   PersonalAccessToken.find_by(token: params[:token])
      #   # good - the example above can be automatically corrected to
      #   PersonalAccessToken.find_by(token: params.permit(:token)[:token])
      #
      #   # bad - otp_code might be an array
      #   MfaValidatorService.new(current_user).execute(params[:otp_code])
      #
      #   # bad - technically OK but better to use StrongParams
      #   MfaValidatorService.new(current_user).execute(params[:otp_code].to_s)
      #
      #   # bad - usually safe, but better to use StrongParams
      #   paginated_resource.page(params[:page]).per(params[:per_page])
      #
      #   # bad - explicitly permit named parameters instead of allowing anything
      #   MfaValidatorService.new(current_user).execute(params.permit![:otp_code])
      #
      #   # good - using permit inline
      #   MfaValidatorService.new(current_user).execute(params.permit(:otp_code)[:otp_code])
      #
      #   # good - using permit via a helper method
      #   def otp_params
      #     params.permit(:otp_code)
      #   end
      #   MfaValidatorService.new(current_user).execute(otp_params[:otp_code])
      #
      #   # good - using require and permit
      #   User.find_by(email: params.require(:user).permit(:email)[:email])
      #
      class StrongParams < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Pass ActionController::StrongParameters in arguments ' \
          'instead of unsanitized ActionController::Parameters.'

        RESTRICT_ON_SEND = %i[params].freeze

        # params is only permitted if require or permit are called on it
        def_node_matcher :safe_params?, <<~PATTERN
          (send
            (send nil? :params) {:require :required :permit}
            ...
          )
        PATTERN

        def_node_matcher :unsafe_hash_access?, <<~PATTERN
          (send
            (send nil? :params) :[]
            ...
          )
        PATTERN

        def on_send(node)
          # We need to look at the parent of the `params` node to see the
          # context in which it is being called and what methods, if any,
          # are being called on it.
          parent = node.parent

          return if parent.nil?
          return if safe_params?(parent)

          add_offense(node) do |corrector|
            # We can auto-correct the simple case of `params[:key]`.
            #
            # The node returned is not exactly equivalent. It is therefore
            # an "unsafe" autocorrection for RuboCop.
            #
            # It will return a permitted key which might be nil if, for
            # example, the value at the key is not a permitted Scalar.
            # See: https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-permit
            if unsafe_hash_access? parent
              corrector.replace(parent, parent.source.sub(/params\[([^\]]+)\]/, "params.permit(\\1)[\\1]"))
            end

            # We can't auto-correct `params` because we don't know what
            # keys to require / permit
          end
        end
      end
    end
  end
end
