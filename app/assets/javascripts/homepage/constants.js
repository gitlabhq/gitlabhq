import { __, s__ } from '~/locale';

export const GREETING_MESSAGES = [
  s__('Homepage|Hey there!'),
  s__('Homepage|Happy coding!'),
  s__('Homepage|Ready to build something great?'),
  s__('Homepage|Ready to ship?'),
  s__("Homepage|Let's get started"),
  s__('Homepage|Great to have you here'),
  s__('Homepage|What will you create today?'),
  s__('Homepage|Welcome!'),
  s__('Homepage|Hello!'),
  s__('Homepage|Nice to see you'),
  s__('Homepage|Hope your day is going well'),
  s__("Homepage|What's on your list today?"),
  s__('Homepage|Time to make things happen'),
  s__('Homepage|Another great day to code!'),
  s__('Homepage|You got this!'),
  s__('Homepage|Onwards!'),
  s__('Homepage|What are you working on today?'),
  s__('Homepage|Ship something awesome'),
  s__('Homepage|A new day for new merge requests'),
  s__('Homepage|Ready when you are'),
  s__("Homepage|Let's get things done"),
  s__('Homepage|Ready, set, go'),
  s__('Homepage|Dive right in'),
  s__('Homepage|Great to see you again!'),
  s__("Homepage|Let's make today count"),
  s__('Homepage|Big things await'),
  s__('Homepage|Hey you!'),
  s__('Homepage|Start small. Ship big.'),
  s__('Homepage|Collaborate. Build. Repeat.'),
  s__("Homepage|Today's a great day to ship"),
  s__('Homepage|No errors, no problems, just great code'),
  s__('Homepage|You made it through the last deploy!'),
  s__('Homepage|Commit early, commit often'),
  s__('Homepage|Here we go'),
  s__("Homepage|Let's go!"),
  s__("Homepage|Whenever you're ready"),
  s__('Homepage|Make it worthwhile'),
  s__('Homepage|Good is about to happen'),
  s__('Homepage|Your corner of GitLab'),
  s__('Homepage|Come on in'),
  s__('Homepage|Small contributions beat big intentions'),
  s__('Homepage|It all started with a commit'),
  s__('Homepage|Rebasing: still not fun'),
  s__('Homepage|Git happens'),
  s__('Homepage|It works on my machine'),
  s__('Homepage|Warning: high productivity detected'),
  s__("Homepage|It's not a bug, it's a feature"),
];

export const DAY_NAMES = [
  __('Sunday'),
  __('Monday'),
  __('Tuesday'),
  __('Wednesday'),
  __('Thursday'),
  __('Friday'),
  __('Saturday'),
];

export const MORNING_GREETINGS = [
  s__('Homepage|Good morning'),
  s__('Homepage|Rise and ship!'),
  s__('Homepage|Fresh start, fresh code'),
  s__('Homepage|Coffee and GitLab'),
];

export const AFTERNOON_GREETINGS = [
  s__('Homepage|Good afternoon'),
  s__('Homepage|Afternoon, keep it up'),
  s__('Homepage|Halfway through the day'),
];

export const EVENING_GREETINGS = [
  s__('Homepage|Good evening'),
  s__('Homepage|Evening? Challenge accepted.'),
  s__('Homepage|Late night coding session?'),
];

export const MONDAY_GREETINGS = [
  s__('Homepage|Make it a mighty Monday'),
  s__("Homepage|Monday. Let's do this."),
];

export const TUESDAY_GREETINGS = [
  s__('Homepage|Your best Tuesday ever'),
  s__("Homepage|It's Tuesday, let's code"),
];

export const WEDNESDAY_GREETINGS = [
  s__('Homepage|Wednesday is looking good'),
  s__("Homepage|Wednesday. Let's keep going."),
];

export const THURSDAY_GREETINGS = [
  s__('Homepage|A thoughtful Thursday to build things'),
  s__("Homepage|Thursday. You've got this."),
];

export const FRIDAY_GREETINGS = [
  s__('Homepage|A fantastic Friday to ship'),
  s__('Homepage|Friday mode: activated'),
];

export const SATURDAY_GREETINGS = [
  s__('Homepage|A sparkling Saturday to make things happen'),
  s__('Homepage|Saturday is looking good'),
];

export const SUNDAY_GREETINGS = [
  s__('Homepage|A sunny Sunday to create'),
  s__('Homepage|Sunday is looking good'),
];

export const PROJECT_SOURCE_FRECENT = 'FRECENT';
export const PROJECT_SOURCE_STARRED = 'STARRED';
export const PROJECT_SOURCE_PERSONAL = 'PERSONAL';

export const PROJECT_SOURCE_LABELS = {
  [PROJECT_SOURCE_FRECENT]: __('Frequently visited'),
  [PROJECT_SOURCE_PERSONAL]: __('Personal'),
  [PROJECT_SOURCE_STARRED]: __('Starred'),
};

export const DEFAULT_PROJECT_SOURCES = [PROJECT_SOURCE_FRECENT];
