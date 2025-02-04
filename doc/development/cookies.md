---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Cookies
---

In general, there is usually a better place to store data for users than in cookies. For backend development PostgreSQL, Redis, and [session storage](session.md) are available. For frontend development, cookies may be more secure than `localStorage`, `IndexedDB` or other options.

In general do not put sensitive information such as user IDs, potentially user-identifying information, tokens, or other secrets into cookies. See our [Secure Coding Guidelines](secure_coding_guidelines.md) for more information.

## Cookies on Rails

Ruby on Rails has cookie setting and retrieval [built-in to ActionController](https://guides.rubyonrails.org/action_controller_overview.html#cookies). Rails uses a cookie to track the user's session ID, which allows access to session storage. [Devise also sets a cookie](https://github.com/heartcombo/devise/blob/main/lib/devise/strategies/rememberable.rb) when users select the **Remember Me** checkbox when signing in, which allows a user to re-authenticate after closing and re-opening a browser.

You can [set cookies with options](https://api.rubyonrails.org/v7.1.3.4/classes/ActionDispatch/Cookies.html) such as `:path` , `:expires`, `:domain` , and `:httponly` . Do not change from the defaults for these options unless it is required for the functionality you are implementing.

WARNING:
[Cookies set by GitLab are unset by default when users log out](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/controllers/sessions_controller.rb#L104). If you set a cookie with the `:domain` option, that cookie must be unset using the same `:domain` parameter. Otherwise the browser will not actually clear the cookie, and we risk persisting potentially-sensitive data which should have been cleared.

## Cookies in Frontend Code

Some of our frontend code sets cookies for persisting data during a session, such as dismissing alerts or sidebar position preferences. We use the [`setCookie` and `getCookie` helpers from `common_utils`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/lib/utils/common_utils.js#L697) to apply reasonable defaults to these cookies.

Be aware that, after 2021, browsers have started [aggressively purging cookies](https://clearcode.cc/blog/browsers-first-third-party-cookies/) and `localStorage` data set by JavaScript scripts in an effort to fight tracking scripts. If cookies seem to be unset every day or every few days, it is possible the data is getting purged, and you might want to preserve the data server-side rather than in browser-local storage.
