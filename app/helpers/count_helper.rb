# frozen_string_literal: true

module CountHelper
  def approximate_count_with_delimiters(count_data, model)
    count = count_data[model]

    raise "Missing model #{model} from count data" unless count

    number_with_delimiter(count)
  end

  # This will approximate the fork count by checking all counting all fork network
  # memberships, and deducting 1 for each root of the fork network.
  # This might be inaccurate as the root of the fork network might have been deleted.
  #
  # This makes querying this information a lot more efficient and it should be
  # accurate enough for the instance wide statistics
  def approximate_fork_count_with_delimiters(count_data)
    fork_network_count = count_data[ForkNetwork]
    fork_network_member_count = count_data[ForkNetworkMember]
    approximate_fork_count = fork_network_member_count - fork_network_count

    number_with_delimiter(approximate_fork_count)
  end
end
