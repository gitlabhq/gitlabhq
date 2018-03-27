class FetchSubscriptionPlansService
  URL = 'https://customers.gitlab.com/gitlab_plans'.freeze

  def initialize(plan:)
    @plan = plan
  end

  def execute
    cached { send_request }
  end

  private

  def send_request
    response = Gitlab::HTTP.get(URL,
                                allow_local_requests: true,
                                query: { plan: @plan },
                                headers: { 'Accept' => 'application/json' })

    JSON.parse(response.body).map { |plan| Hashie::Mash.new(plan) }
  rescue => e
    Rails.logger.info "Unable to connect to GitLab Customers App #{e}"

    nil
  end

  def cached
    if plans_data = cache.read(cache_key)
      plans_data
    else
      cache.fetch(cache_key, force: true, expires_in: 1.day) { yield }
    end
  end

  def cache
    Rails.cache
  end

  def cache_key
    "subscription-plans-#{@plan}"
  end
end
