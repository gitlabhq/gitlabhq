require 'spec_helper'

describe SidekiqHelper do
  describe 'parse_sidekiq_ps' do
    it 'parses line with time' do
      line = '55137	10,0	2,1	S+	2:30pm	sidekiq 4.1.4 gitlab [0 of 25 busy]   '
      parts = helper.parse_sidekiq_ps(line)
      expect(parts).to eq(['55137', '10,0', '2,1', 'S+', '2:30pm', 'sidekiq 4.1.4 gitlab [0 of 25 busy]'])
    end

    it 'parses line with date' do
      line = '55137	10,0	2,1	S+	Aug 4	sidekiq 4.1.4 gitlab [0 of 25 busy]   '
      parts = helper.parse_sidekiq_ps(line)
      expect(parts).to eq(['55137', '10,0', '2,1', 'S+', 'Aug 4', 'sidekiq 4.1.4 gitlab [0 of 25 busy]'])
    end

    it 'parses line with two digit date' do
      line = '55137	10,0	2,1	S+	Aug 04	sidekiq 4.1.4 gitlab [0 of 25 busy]   '
      parts = helper.parse_sidekiq_ps(line)
      expect(parts).to eq(['55137', '10,0', '2,1', 'S+', 'Aug 04', 'sidekiq 4.1.4 gitlab [0 of 25 busy]'])
    end

    it 'parses line with dot as float separator' do
      line = '55137	10.0	2.1	S+	2:30pm	sidekiq 4.1.4 gitlab [0 of 25 busy]   '
      parts = helper.parse_sidekiq_ps(line)
      expect(parts).to eq(['55137', '10.0', '2.1', 'S+', '2:30pm', 'sidekiq 4.1.4 gitlab [0 of 25 busy]'])
    end

    it 'does fail gracefully on line not matching the format' do
      line = '55137	10.0	2.1	S+	2:30pm	something'
      parts = helper.parse_sidekiq_ps(line)
      expect(parts).to eq(['?', '?', '?', '?', '?', '?'])
    end
  end
end
