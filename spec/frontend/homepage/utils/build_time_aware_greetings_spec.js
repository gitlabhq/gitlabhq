import {
  buildTimeAwareGreetings,
  getRandomGreeting,
} from '~/homepage/utils/build_time_aware_greetings';
import { GREETING_MESSAGES, MORNING_GREETINGS, EVENING_GREETINGS } from '~/homepage/constants';

describe('buildTimeAwareGreetings', () => {
  describe('time-of-day greetings', () => {
    it.each`
      hour  | description    | expected
      ${8}  | ${'morning'}   | ${['Good morning', 'Rise and ship!', 'Fresh start, fresh code', 'Coffee and GitLab']}
      ${14} | ${'afternoon'} | ${['Good afternoon', 'Afternoon, keep it up', 'Halfway through the day']}
      ${22} | ${'evening'}   | ${['Good evening', 'Evening? Challenge accepted.', 'Late night coding session?']}
      ${0}  | ${'midnight'}  | ${['Good evening', 'Evening? Challenge accepted.', 'Late night coding session?']}
    `('returns $description greetings at hour $hour', ({ hour, expected }) => {
      const greetings = buildTimeAwareGreetings(new Date(2025, 2, 19, hour, 0));
      expect(greetings).toEqual(expect.arrayContaining(expected));
    });
  });

  describe('happy day greetings', () => {
    it.each`
      date  | dayName        | expected
      ${23} | ${'Sunday'}    | ${'Happy Sunday!'}
      ${17} | ${'Monday'}    | ${'Happy Monday!'}
      ${18} | ${'Tuesday'}   | ${'Happy Tuesday!'}
      ${19} | ${'Wednesday'} | ${'Happy Wednesday!'}
      ${20} | ${'Thursday'}  | ${'Happy Thursday!'}
      ${21} | ${'Friday'}    | ${'Happy Friday!'}
      ${22} | ${'Saturday'}  | ${'Happy Saturday!'}
    `('includes "$expected" on $dayName', ({ date, expected }) => {
      const greetings = buildTimeAwareGreetings(new Date(2025, 2, date, 10, 0));
      expect(greetings).toContain(expected);
    });

    it('does not include other days happy greeting', () => {
      const greetings = buildTimeAwareGreetings(new Date(2025, 2, 18, 10, 0)); // Tuesday
      expect(greetings).toContain('Happy Tuesday!');
      expect(greetings).not.toContain('Happy Saturday!');
    });
  });

  describe('day-of-week greetings', () => {
    it.each`
      date  | dayName        | expected
      ${23} | ${'Sunday'}    | ${['A sunny Sunday to create', 'Sunday is looking good']}
      ${17} | ${'Monday'}    | ${['Make it a mighty Monday', "Monday. Let's do this."]}
      ${18} | ${'Tuesday'}   | ${['Your best Tuesday ever', "It's Tuesday, let's code"]}
      ${19} | ${'Wednesday'} | ${['Wednesday is looking good', "Wednesday. Let's keep going."]}
      ${20} | ${'Thursday'}  | ${['A thoughtful Thursday to build things', "Thursday. You've got this."]}
      ${21} | ${'Friday'}    | ${['A fantastic Friday to ship', 'Friday mode: activated']}
      ${22} | ${'Saturday'}  | ${['A sparkling Saturday to make things happen', 'Saturday is looking good']}
    `('includes $dayName greetings on $dayName', ({ date, expected }) => {
      const greetings = buildTimeAwareGreetings(new Date(2025, 2, date, 10, 0));
      expect(greetings).toEqual(expect.arrayContaining(expected));
    });

    it('does not include other days greetings', () => {
      const greetings = buildTimeAwareGreetings(new Date(2025, 2, 18, 10, 0)); // Tuesday
      expect(greetings).not.toEqual(
        expect.arrayContaining([
          'A sparkling Saturday to make things happen',
          'Saturday is looking good',
        ]),
      );
    });
  });
});

describe('getRandomGreeting', () => {
  const wednesdayMorning = new Date(2025, 2, 19, 10, 0);

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('returns a string from the combined greeting pool', () => {
    const allGreetings = [...GREETING_MESSAGES, ...buildTimeAwareGreetings(wednesdayMorning)];
    const result = getRandomGreeting(wednesdayMorning);
    expect(allGreetings).toContain(result);
  });

  it('returns the first greeting when Math.random returns 0', () => {
    jest.spyOn(Math, 'random').mockReturnValue(0);
    const allGreetings = [...GREETING_MESSAGES, ...buildTimeAwareGreetings(wednesdayMorning)];
    expect(getRandomGreeting(wednesdayMorning)).toBe(allGreetings[0]);
  });

  it('returns the last greeting when Math.random returns 0.999', () => {
    jest.spyOn(Math, 'random').mockReturnValue(0.999);
    const allGreetings = [...GREETING_MESSAGES, ...buildTimeAwareGreetings(wednesdayMorning)];
    expect(getRandomGreeting(wednesdayMorning)).toBe(allGreetings[allGreetings.length - 1]);
  });

  it('passes the date parameter to buildTimeAwareGreetings', () => {
    const eveningDate = new Date(2025, 2, 19, 22, 0); // Wednesday 10pm
    const eveningPool = [...GREETING_MESSAGES, ...buildTimeAwareGreetings(eveningDate)];

    // Locate an evening-only greeting in the pool (one that would never appear
    // when the date is in the morning), then make Math.random pick that index.
    const morningOnly = MORNING_GREETINGS.filter((g) => !EVENING_GREETINGS.includes(g));
    const eveningOnlyIndex = eveningPool.findIndex((g) => EVENING_GREETINGS.includes(g));
    expect(eveningOnlyIndex).toBeGreaterThan(-1);

    // Math.floor(random * pool.length) === eveningOnlyIndex when
    // random is at the start of that index's bucket.
    jest.spyOn(Math, 'random').mockReturnValue(eveningOnlyIndex / eveningPool.length + 1e-9);

    const result = getRandomGreeting(eveningDate);

    expect(eveningPool).toContain(result);
    expect(EVENING_GREETINGS).toContain(result);
    expect(morningOnly).not.toContain(result);
  });
});
