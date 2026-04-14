import { s__, sprintf } from '~/locale';
import {
  MORNING_GREETINGS,
  AFTERNOON_GREETINGS,
  EVENING_GREETINGS,
  SUNDAY_GREETINGS,
  MONDAY_GREETINGS,
  TUESDAY_GREETINGS,
  WEDNESDAY_GREETINGS,
  THURSDAY_GREETINGS,
  FRIDAY_GREETINGS,
  SATURDAY_GREETINGS,
  DAY_NAMES,
} from '~/homepage/constants';

const DAY_GREETINGS = [
  SUNDAY_GREETINGS,
  MONDAY_GREETINGS,
  TUESDAY_GREETINGS,
  WEDNESDAY_GREETINGS,
  THURSDAY_GREETINGS,
  FRIDAY_GREETINGS,
  SATURDAY_GREETINGS,
];

/**
 * Returns time-aware greetings based on the user's local time and day of week.
 * @param {Date} now - The current date/time (defaults to new Date())
 * @returns {string[]} Array of contextual greeting strings
 */
export function buildTimeAwareGreetings(now = new Date()) {
  const hour = now.getHours();
  const day = now.getDay();
  const greetings = [];

  // Happy <day of week>!
  greetings.push(sprintf(s__('Homepage|Happy %{dayName}!'), { dayName: DAY_NAMES[day] }, false));

  // Time-of-day greetings
  if (hour >= 5 && hour < 12) {
    greetings.push(...MORNING_GREETINGS);
  } else if (hour >= 12 && hour < 18) {
    greetings.push(...AFTERNOON_GREETINGS);
  } else {
    greetings.push(...EVENING_GREETINGS);
  }

  // Day-of-week greetings
  greetings.push(...DAY_GREETINGS[day]);

  return greetings;
}
