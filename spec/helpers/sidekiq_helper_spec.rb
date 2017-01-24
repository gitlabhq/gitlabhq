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

    it 'parses OSX output' do
      line = ' 1641   1.5  3.8 S+    4:04PM sidekiq 4.2.1 gitlab [0 of 25 busy]'
      parts = helper.parse_sidekiq_ps(line)

      expect(parts).to eq(['1641', '1.5', '3.8', 'S+', '4:04PM', 'sidekiq 4.2.1 gitlab [0 of 25 busy]'])
    end

    it 'parses Ubuntu output' do
      # Ubuntu Linux 16.04 LTS / procps-3.3.10-4ubuntu2
      line = '  938  1.4  2.5 Sl+  21:23:21 sidekiq 4.2.1 gitlab [0 of 25 busy]   '
      parts = helper.parse_sidekiq_ps(line)

      expect(parts).to eq(['938', '1.4', '2.5', 'Sl+', '21:23:21', 'sidekiq 4.2.1 gitlab [0 of 25 busy]'])
    end

    it 'parses Debian output' do
      # Debian Linux Wheezy/Jessie
      line = '17725  1.0 12.1 Ssl  19:20:15 sidekiq 4.2.1 gitlab-rails [0 of 25 busy]   '
      parts = helper.parse_sidekiq_ps(line)

      expect(parts).to eq(['17725', '1.0', '12.1', 'Ssl', '19:20:15', 'sidekiq 4.2.1 gitlab-rails [0 of 25 busy]'])
    end

    it 'does fail gracefully on line not matching the format' do
      line = '55137	10.0	2.1	S+	2:30pm	something'
      parts = helper.parse_sidekiq_ps(line)

      expect(parts).to eq(['?', '?', '?', '?', '?', '?'])
    end
  end
end
