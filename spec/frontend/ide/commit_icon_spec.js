import getCommitIconMap from '~/ide/commit_icon';
import { commitItemIconMap } from '~/ide/constants';
import { decorateData } from '~/ide/stores/utils';

// eslint-disable-next-line max-params
const createFile = (name = 'name', id = name, type = '', parent = null) =>
  decorateData({
    id,
    type,
    icon: 'icon',
    name,
    path: parent ? `${parent.path}/${name}` : name,
    parentPath: parent ? parent.path : '',
  });

describe('getCommitIconMap', () => {
  let entry;

  beforeEach(() => {
    entry = createFile('Entry item');
  });

  it('renders "deleted" icon for deleted entries', () => {
    entry.deleted = true;
    expect(getCommitIconMap(entry)).toEqual(commitItemIconMap.deleted);
  });

  it('renders "addition" icon for temp entries', () => {
    entry.tempFile = true;
    expect(getCommitIconMap(entry)).toEqual(commitItemIconMap.addition);
  });

  it('renders "modified" icon for newly-renamed entries', () => {
    entry.prevPath = 'foo/bar';
    entry.tempFile = false;
    expect(getCommitIconMap(entry)).toEqual(commitItemIconMap.modified);
  });

  it('renders "modified" icon even for temp entries if they are newly-renamed', () => {
    entry.prevPath = 'foo/bar';
    entry.tempFile = true;
    expect(getCommitIconMap(entry)).toEqual(commitItemIconMap.modified);
  });
});
