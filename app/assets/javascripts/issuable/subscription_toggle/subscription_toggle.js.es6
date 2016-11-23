//  - if current_user
//   - subscribed = issuable.subscribed?(current_user, @project)
//   .block.light.subscription{data: {url: toggle_subscription_path(issuable)}}
//     .sidebar-collapsed-icon
//       = icon('rss')
//     .title.hide-collapsed
//       Notifications
//     - subscribtion_status = subscribed ? 'subscribed' : 'unsubscribed'
//     %button.btn.btn-block.btn-default.js-subscribe-button.issuable-subscribe-button.hide-collapsed{ type: "button" }
//       %span= subscribed ? 'Unsubscribe' : 'Subscribe'
//     .subscription-status.hide-collapsed{data: {status: subscribtion_status}}
//       .unsubscribed{class: ( 'hidden' if subscribed )}
//         You're not receiving notifications from this thread.
//       .subscribed{class: ( 'hidden' unless subscribed )}
//         You're receiving notifications because you're subscribed to this thread.