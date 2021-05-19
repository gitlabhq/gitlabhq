# frozen_string_literal: true

module Gitlab
  class MultiCollectionPaginator
    attr_reader :first_collection, :second_collection, :per_page

    def initialize(*collections, per_page: nil)
      raise ArgumentError, 'Only 2 collections are supported' if collections.size != 2

      @per_page = (per_page || Kaminari.config.default_per_page).to_i
      @first_collection, @second_collection = collections
    end

    def paginate(page)
      page = page.to_i
      paginated_first_collection(page) + paginated_second_collection(page)
    end

    def total_count
      @total_count ||= first_collection.size + second_collection.size
    end

    private

    def paginated_first_collection(page)
      @first_collection_pages ||= Hash.new do |hash, page|
        hash[page] = first_collection.page(page).per(per_page)
      end

      @first_collection_pages[page]
    end

    def paginated_second_collection(page)
      @second_collection_pages ||= Hash.new do |hash, page|
        second_collection_page = page - first_collection_page_count

        offset = if second_collection_page < 1 || first_collection_page_count == 0
                   0
                 else
                   per_page - first_collection_last_page_size
                 end

        hash[page] = second_collection.page(second_collection_page)
                       .per(per_page - paginated_first_collection(page).size)
                       .padding(offset)
      end

      @second_collection_pages[page]
    end

    def first_collection_page_count
      return @first_collection_page_count if defined?(@first_collection_page_count)

      first_collection_page = paginated_first_collection(0)
      @first_collection_page_count = first_collection_page.total_pages
    end

    def first_collection_last_page_size
      return @first_collection_last_page_size if defined?(@first_collection_last_page_size)

      @first_collection_last_page_size = paginated_first_collection(first_collection_page_count)
                                           .except(:select)
                                           .size
    end
  end
end
