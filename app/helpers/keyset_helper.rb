# frozen_string_literal: true

module KeysetHelper
  def keyset_paginate(paginator, without_first_and_last_pages: false, permitted_params: {})
    page_params = params.permit(permitted_params).to_h

    render('kaminari/gitlab/keyset_paginator', {
      paginator: paginator,
      without_first_and_last_pages: without_first_and_last_pages,
      page_params: page_params
    })
  end
end
