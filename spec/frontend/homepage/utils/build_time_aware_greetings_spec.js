import { buildTimeAwareGreetings } from '~/homepage/utils/build_time_aware_greetings';

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
