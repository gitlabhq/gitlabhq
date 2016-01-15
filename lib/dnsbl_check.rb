require 'resolv'

class DNSBLCheck

  class Resolver
    def self.search(query)
      begin
        Resolv.getaddress(query)
        true
      rescue Resolv::ResolvError
        false
      end
    end
  end

  IP_REGEXP = /\A([0-9]{1,3}\.){3}[0-9]{1,3}\z/
  DEFAULT_TRESHOLD = 0.33

  class << self

    def test(ip)
      return false unless enabled

      search(ip)
      final_score > treshold
    end

    def test_strict(ip)
      return false unless enabled

      search(ip)
      @score > 0
    end

    def enabled=(enabled)
      @enabled = enabled && true
    end

    def enabled
      @enabled ||= false
    end

    def treshold=(treshold)
      raise ArgumentError, "'treshold' value must be grather than 0 and less/equal 1" unless treshold.between?(0, 1) && treshold > 0
      @treshold = treshold
    end

    def treshold
      @treshold ||= DEFAULT_TRESHOLD
    end

    def add_dnsbl(domain, weight)
      @dnsbls ||= []
      @dnsbls << { domain: domain, weight: weight }
    end

    def dnsbls
      @dnsbls ||= []
    end

    private

    def search(ip)
      raise ArgumentError, "'ip' value must be in #{IP_REGEXP} format" unless ip.match(IP_REGEXP)

      @score = 0

      reversed = reverse_ip(ip)
      search_in_rbls(reversed)
    end

    def reverse_ip(ip)
      ip.split('.').reverse.join('.')
    end

    def search_in_rbls(reversed_ip)
      dnsbls.each do |rbl|
        query = "#{reversed_ip}.#{rbl[:domain]}"
        @score += rbl[:weight] if Resolver.search(query)
      end
    end

    def final_score
      weights = dnsbls.map{ |rbl| rbl[:weight] }.reduce(:+).to_i
      return 0 if weights == 0

      @score /= weights
      @score.round(2)
    end
  end
end
