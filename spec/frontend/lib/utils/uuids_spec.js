import { uuids } from '~/lib/utils/uuids';

const HEX = /[a-f0-9]/i;
const HEX_RE = HEX.source;
const UUIDV4 = new RegExp(
  `${HEX_RE}{8}-${HEX_RE}{4}-4${HEX_RE}{3}-[89ab]${HEX_RE}{3}-${HEX_RE}{12}`,
  'i',
);

describe('UUIDs Util', () => {
  describe('uuids', () => {
    const SEQUENCE_FOR_GITLAB_SEED = [
      'a1826a44-316c-480e-a93d-8cdfeb36617c',
      'e049db1f-a4cf-4cba-aa60-6d95e3b547dc',
      '6e3c737c-13a7-4380-b17d-601f187d7e69',
      'bee5cc7f-c486-45c0-8ad3-d1ac5402632d',
      'af248c9f-a3a6-4d4f-a311-fe151ffab25a',
    ];
    const SEQUENCE_FOR_12345_SEED = [
      'edfb51e2-e3e1-4de5-90fd-fd1d21760881',
      '2f154da4-0a2d-4da9-b45e-0ffed391517e',
      '91566d65-8836-4222-9875-9e1df4d0bb01',
      'f6ea6c76-7640-4d71-a736-9d3bec7a1a8e',
      'bfb85869-5fb9-4c5b-a750-5af727ac5576',
    ];

    it('returns version 4 UUIDs', () => {
      expect(uuids()[0]).toMatch(UUIDV4);
    });

    it('outputs an array of UUIDs', () => {
      const ids = uuids({ count: 11 });

      expect(ids.length).toEqual(11);
      expect(ids.every((id) => UUIDV4.test(id))).toEqual(true);
    });

    it.each`
      seeds                          | uuid
      ${['some', 'special', 'seed']} | ${'6fa53e51-0f70-4072-9c84-1c1eee1b9934'}
      ${['magic']}                   | ${'fafae8cd-7083-44f3-b82d-43b30bd27486'}
      ${['seeded']}                  | ${'e06ed291-46c5-4e42-836b-e7c772d48b49'}
      ${['GitLab']}                  | ${'a1826a44-316c-480e-a93d-8cdfeb36617c'}
      ${['JavaScript']}              | ${'12dfb297-1560-4c38-9775-7178ef8472fb'}
      ${[99, 169834, 2619]}          | ${'3ecc8ad6-5b7c-4c9b-94a8-c7271c2fa083'}
      ${[12]}                        | ${'2777374b-723b-469b-bd73-e586df964cfd'}
      ${[9876, 'mixed!', 7654]}      | ${'865212e0-4a16-4934-96f9-103cf36a6931'}
      ${[123, 1234, 12345, 6]}       | ${'40aa2ee6-0a11-4e67-8f09-72f5eba04244'}
      ${[0]}                         | ${'8c7f0aac-97c4-4a2f-b716-a675d821ccc0'}
    `(
      'should always output the UUID $uuid when the options.seeds argument is $seeds',
      ({ uuid, seeds }) => {
        expect(uuids({ seeds })[0]).toEqual(uuid);
      },
    );

    describe('unseeded UUID randomness', () => {
      const nonRandom = Array(6)
        .fill(0)
        .map((_, i) => uuids({ seeds: [i] })[0]);
      const random = uuids({ count: 6 });
      const moreRandom = uuids({ count: 6 });

      it('is different from a seeded result', () => {
        random.forEach((id, i) => {
          expect(id).not.toEqual(nonRandom[i]);
        });
      });

      it('is different from other random results', () => {
        random.forEach((id, i) => {
          expect(id).not.toEqual(moreRandom[i]);
        });
      });

      it('never produces any duplicates', () => {
        expect(new Set(random).size).toEqual(random.length);
      });
    });

    it.each`
      seed        | sequence
      ${'GitLab'} | ${SEQUENCE_FOR_GITLAB_SEED}
      ${12345}    | ${SEQUENCE_FOR_12345_SEED}
    `(
      'should output the same sequence of UUIDs for the given seed "$seed"',
      ({ seed, sequence }) => {
        expect(uuids({ seeds: [seed], count: 5 })).toEqual(sequence);
      },
    );
  });
});
