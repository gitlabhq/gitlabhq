namespace :gitlab do
  namespace :features do
    desc 'GitLab | Features | Enable direct Git access via Rugged for NFS'
    task enable_rugged: :environment do
      set_rugged_feature_flags(true)
      puts 'All Rugged feature flags were enabled.'
    end

    task disable_rugged: :environment do
      set_rugged_feature_flags(false)
      puts 'All Rugged feature flags were disabled.'
    end

    task unset_rugged: :environment do
      set_rugged_feature_flags(nil)
      puts 'All Rugged feature flags were unset.'
    end
  end

  def set_rugged_feature_flags(status)
    Gitlab::Git::RuggedImpl::Repository::FEATURE_FLAGS.each do |flag|
      case status
      when nil
        Feature.get(flag).remove
      when true
        Feature.enable(flag)
      when false
        Feature.disable(flag)
      end
    end
  end
end
