require 'resolv'

class DNSXLCheck

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
  DEFAULT_THRESHOLD = 0.33

  def self.create_from_list(list)
    dnsxl_check = DNSXLCheck.new

    list.each do |entry|
      dnsxl_check.add_list(entry.domain, entry.weight)
    end

    dnsxl_check
  end

  def test(ip)
    search(ip)
    final_score > threshold
  end

  def test_strict(ip)
    search(ip)
    @score > 0
  end

  def threshold=(threshold)
    raise ArgumentError, "'threshold' value must be grather than 0 and less/equal 1" unless threshold.between?(0, 1) && threshold > 0
    @threshold = threshold
  end

  def threshold
    @threshold ||= DEFAULT_THRESHOLD
  end

  def add_list(domain, weight)
    @lists ||= []
    @lists << { domain: domain, weight: weight }
  end

  def lists
    @lists ||= []
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
    lists.each do |rbl|
      query = "#{reversed_ip}.#{rbl[:domain]}"
      @score += rbl[:weight] if Resolver.search(query)
    end
  end

  def final_score
    weights = lists.map{ |rbl| rbl[:weight] }.reduce(:+).to_i
    return 0 if weights == 0

    @score /= weights
    @score.round(2)
  end
end
