import { setTitle } from '~/repository/utils/title';

describe('setTitle', () => {
  it.each`
    path                        | title
    ${'/'}                      | ${'Files'}
    ${'app'}                    | ${'app'}
    ${'app/assets'}             | ${'app/assets'}
    ${'app/assets/javascripts'} | ${'app/assets/javascripts'}
  `('sets document title as $title for $path', ({ path, title }) => {
    setTitle(path, 'master', 'GitLab Org / GitLab');

    expect(document.title).toEqual(`${title} · master · GitLab Org / GitLab · GitLab`);
  });
});
