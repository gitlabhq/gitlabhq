# frozen_string_literal: true

Rails.application.routes.draw do
  draw_all :api
  draw_all :admin
  draw_all :public
end
