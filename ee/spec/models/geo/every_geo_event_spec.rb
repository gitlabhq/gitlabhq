require 'spec_helper'

describe 'Every Geo event' do
  subject { events }

  it 'includes Geo::Eventable' do
    is_expected.to all( satisfy { |klass| klass.ancestors.include?(Geo::Eventable)  })
  end

  it 'has its class in Geo::EventLog::EVENT_CLASSES' do
    expect(subject.map(&:name)).to match_array(Geo::EventLog::EVENT_CLASSES)
  end

  def events
    root  = Rails.root.join('ee', 'app', 'models')
    geo   = root.join('geo')

    events = Dir[geo.join('**', '*.rb')]
      .select { |path| path.end_with?('_event.rb') }

    events.map! do |path|
      ns = Pathname.new(path).relative_path_from(root).to_s.gsub('.rb', '')
      ns.camelize.constantize
    end

    # Skip things that aren't models
    events.select { |event| event < ActiveRecord::Base }
  end
end
