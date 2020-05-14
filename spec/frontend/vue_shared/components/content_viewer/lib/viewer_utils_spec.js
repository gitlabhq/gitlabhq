import { viewerInformationForPath } from '~/vue_shared/components/content_viewer/lib/viewer_utils';

describe('viewerInformationForPath', () => {
  it.each`
    path                 | type
    ${'p/somefile.jpg'}  | ${'image'}
    ${'p/somefile.jpeg'} | ${'image'}
    ${'p/somefile.bmp'}  | ${'image'}
    ${'p/somefile.ico'}  | ${'image'}
    ${'p/somefile.png'}  | ${'image'}
    ${'p/somefile.gif'}  | ${'image'}
    ${'p/somefile.md'}   | ${'markdown'}
    ${'p/md'}            | ${undefined}
    ${'p/png'}           | ${undefined}
    ${'p/md.png/a'}      | ${undefined}
    ${'p/some-file.php'} | ${undefined}
  `('when path=$path, type=$type', ({ path, type }) => {
    expect(viewerInformationForPath(path)?.id).toBe(type);
  });
});
