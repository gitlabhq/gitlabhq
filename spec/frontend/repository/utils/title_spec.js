import { setTitle, updateRefPortionOfTitle } from '~/repository/utils/title';

describe('setTitle', () => {
  it.each`
    path                        | title
    ${'/'}                      | ${'Files'}
    ${'app'}                    | ${'app'}
    ${'app/assets'}             | ${'app/assets'}
    ${'app/assets/javascripts'} | ${'app/assets/javascripts'}
  `('sets document title as $title for $path', ({ path, title }) => {
    setTitle(path, 'main', 'GitLab Org / GitLab');

    expect(document.title).toEqual(`${title} · main · GitLab Org / GitLab · GitLab`);
  });
});

describe('updateRefPortionOfTitle', () => {
  const sha = 'abc';
  const testCases = [
    [
      'updates the title with the SHA',
      { title: 'part 1 · part 2 · part 3' },
      'part 1 · abc · part 3',
    ],
    ["makes no change if there's no title", { foo: null }, undefined],
    [
      "makes no change if the title doesn't split predictably",
      { title: 'part 1 - part 2 - part 3' },
      'part 1 - part 2 - part 3',
    ],
  ];

  it.each(testCases)('%s', (desc, doc, title) => {
    updateRefPortionOfTitle(sha, doc);

    expect(doc.title).toEqual(title);
  });
});
