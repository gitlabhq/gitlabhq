module Projects
  module Settings
    class DeployTokensPresenter < Gitlab::View::Presenter::Simple
      include Enumerable

      presents :deploy_tokens

      def length
        deploy_tokens.length
      end

      def each
        deploy_tokens.each do |deploy_token|
          yield deploy_token
        end
      end
    end
  end
end
