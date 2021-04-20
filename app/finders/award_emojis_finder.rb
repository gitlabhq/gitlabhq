# frozen_string_literal: true

class AwardEmojisFinder
  attr_reader :awardable, :params

  def initialize(awardable, params = {})
    @awardable = awardable
    @params = params

    validate_params
  end

  def execute
    awards = awardable.award_emoji
    awards = by_name(awards)
    by_awarded_by(awards)
  end

  private

  def by_name(awards)
    return awards unless params[:name]

    awards.named(params[:name])
  end

  def by_awarded_by(awards)
    return awards unless params[:awarded_by]

    awards.awarded_by(params[:awarded_by])
  end

  def validate_params
    return unless params.present?

    validate_name_param
    validate_awarded_by_param
  end

  def validate_name_param
    return unless params[:name]

    raise ArgumentError, 'Invalid name param' unless params[:name].to_s.in?(Gitlab::Emoji.emojis_names)
  end

  def validate_awarded_by_param
    return unless params[:awarded_by]

    # awarded_by can be a `User`, or an ID
    unless params[:awarded_by].is_a?(User) || params[:awarded_by].to_s.match(/\A\d+\Z/)
      raise ArgumentError, 'Invalid awarded_by param'
    end
  end
end
