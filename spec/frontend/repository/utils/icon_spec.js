import { getIconName } from '~/repository/utils/icon';

describe('getIconName', () => {
  // Tests the returning font awesome icon name
  // We only test one for each file type to save testing a lot of different
  // file types
  it.each`
    type        | path           | icon
    ${'tree'}   | ${''}          | ${'folder'}
    ${'commit'} | ${''}          | ${'archive'}
    ${'file'}   | ${'test.pdf'}  | ${'file-pdf-o'}
    ${'file'}   | ${'test.jpg'}  | ${'file-image-o'}
    ${'file'}   | ${'test.zip'}  | ${'file-archive-o'}
    ${'file'}   | ${'test.mp3'}  | ${'file-audio-o'}
    ${'file'}   | ${'test.flv'}  | ${'file-video-o'}
    ${'file'}   | ${'test.dotx'} | ${'file-word-o'}
    ${'file'}   | ${'test.xlsb'} | ${'file-excel-o'}
    ${'file'}   | ${'test.ppam'} | ${'file-powerpoint-o'}
    ${'file'}   | ${'test.js'}   | ${'file-text-o'}
  `('returns $icon for $type with path $path', ({ type, path, icon }) => {
    expect(getIconName(type, path)).toEqual(icon);
  });
});
