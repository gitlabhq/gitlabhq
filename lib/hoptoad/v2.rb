module Hoptoad
  module V2
    def self.process_notice(parsed)
      for_errbit_api(
        normalize(
          rekey(parsed)))
    end

  private
    def self.rekey(node)
      case node
      when Hash
        if node.has_key?('var') && node.has_key?('key')
          {normalize_key(node['key']) => rekey(node['var'])}
        elsif node.has_key?('var')
          rekey(node['var'])
        elsif node.has_key?('__content__') && node.has_key?('key')
          {normalize_key(node['key']) => rekey(node['__content__'])}
        elsif node.has_key?('__content__')
          rekey(node['__content__'])
        elsif node.has_key?('key')
          {normalize_key(node['key']) => nil}
        else
          node.inject({}) {|rekeyed, (key, val)| rekeyed.merge(normalize_key(key) => rekey(val))}
        end
      when Array
        if node.first.has_key?('key')
          node.inject({}) {|rekeyed, keypair| rekeyed.merge(rekey(keypair))}
        else
          node.map {|n| rekey(n)}
        end
      else
        node
      end
    end

    def self.normalize_key(key)
      key.gsub('.', '_')
    end

    def self.normalize(notice)
      error = notice['error']
      backtrace = error['backtrace']
      backtrace['line'] = [backtrace['line']] unless backtrace['line'].is_a?(Array)

      notice['request'] ||= {}
      notice['request']['component']  = 'unknown' if notice['request']['component'].blank?
      notice['request']['action']     = nil       if notice['request']['action'].blank?

      notice
    end

    def self.for_errbit_api(notice)
      {
        :error_class        => notice['error']['class'] || notice['error']['key'],
        :message            => notice['error']['message'],
        :backtrace          => notice['error']['backtrace']['line'],

        :request            => notice['request'],
        :server_environment => notice['server-environment'],

        :api_key            => notice['api-key'],
        :notifier           => notice['notifier'],
        # 'current-user' from airbrake, 'user-attributes' from airbrake_user_attributes gem
        :user_attributes    => notice['current-user'] || notice['user-attributes'] || {},
        :framework          => notice['framework']
      }
    end
  end
end
