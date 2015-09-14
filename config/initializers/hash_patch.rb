# We need this patch because of json format error in the CI API:
#   IOError (not opened for reading)
# Details: http://stackoverflow.com/questions/19808921/upgrade-to-rails-4-got-ioerror-not-opened-for-reading
# It happens because of ActiveSupport's monkey patch of json formatters

if defined?(ActiveSupport::JSON)
  Hash.class_eval do
    def to_json(*args)
      super(args)
    end
    def as_json(*args)
      super(args)
    end
  end
end