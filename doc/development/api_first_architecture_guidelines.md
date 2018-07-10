NOTE: The following are discussion topics for now. We should collaborate to
figure out if this is the direction we want to go in.

# API first architecture guidelines

This style makes recommendations about how frontend (JS) code should
interface with our backend (Rails) code. These guidelines are advocating
specifically for Single Page Application architecture but focus on the
implementation in terms of APIs between JS and Ruby that may also be
public APIs as well.

## What is the recommendation?

We would like to ensure that all new UI elements are rendered from client
side JS rather than our previous server side HAML rendering. As we build
new UI elements we should ensure we avoid HAML if possible and only render
HTML from VueJS code.

## Why?

There are several benefits for this architecture (which is essentially the
SPA architecture):

- This will enable frontend developers and backend developers to have
  clearly defined way of collaborating on issues. That is they will work
  together to define the API contract and then they will be able to assume
  that contract and work independently. If we build out our toolset we may
  be able to [automatically generate stub APIs based on these
  - contracts](https://github.com/pact-foundation/pact-ruby) or if we
  start adopting GraphQL then we get similar benefits plus much more.
- This will help a new group of would-be contributors start contributing
  frontend improvements to GitLab. Since the set of JS developers is
  larger than the subset that also are comfortable with diving into the
  Ruby code.
- This may make it easier for the FE teams to operate more efficiently and
  inovate faster since they are able to focus on the technologies that
  they are experts in.
- Public APIs may become something we get for free


## Why not?

There are some tradeoffs we need to accept when adopting this
architecture. We expect the following tradeoffs to arise as we adopt this
(especially early on) and are will to accept these tradeoffs for longer
term benefits:

- The backend developers will be less often able to complete features end
  to end that would ordinarily only require small frontend changes
- The frontend developers will be less often able to complete features end
  to end that would ordinarily only require small backend changes
- The time taken to complete a given feature may be longer because we are
  using a different style of architecture than we are used to
