const LATEST_VERSION = {
  version: '1.2.3',
};

export const makeModel = ({ latestVersion } = { latestVersion: LATEST_VERSION }) => ({
  id: 1234,
  name: 'blah',
  path: 'path/to/blah',
  description: 'Description of the model',
  latestVersion,
  versionCount: 2,
  candidateCount: 1,
});

export const MODEL = makeModel();

export const MODEL_VERSION = { version: '1.2.3', model: MODEL };
