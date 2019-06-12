FROM ruby:2.6.3-alpine
ADD ./ /app/
WORKDIR /app
ENV RACK_ENV production
ENV PORT 5000
EXPOSE 5000

RUN bundle install
CMD ["bundle","exec", "rackup", "-p", "5000"]
