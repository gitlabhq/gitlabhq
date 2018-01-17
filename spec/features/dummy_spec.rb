require 'spec_helper'
require 'net/http'

feature 'dummy feature' do
  scenario 'deletes something', :js do
    visit root_path

    url = URI.parse(evaluate_script('location.origin') + '/api/v4/something')
    req = Net::HTTP::Delete.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }

    puts res.code
    puts res.body
  end

  scenario 'deletes something with JavaScript', :js do
    visit root_path

    url = URI.parse(evaluate_script('location.origin') + '/api/v4/something')
    req = Net::HTTP::Delete.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }

    puts res.code
    puts res.body
  end
end
