const entryTypeIcons = {
  tree: 'folder',
  commit: 'archive',
};

const fileTypeIcons = [
  { extensions: ['pdf'], name: 'file-pdf-o' },
  {
    extensions: [
      'jpg',
      'jpeg',
      'jif',
      'jfif',
      'jp2',
      'jpx',
      'j2k',
      'j2c',
      'png',
      'gif',
      'tif',
      'tiff',
      'svg',
      'ico',
      'bmp',
    ],
    name: 'file-image-o',
  },
  {
    extensions: ['zip', 'zipx', 'tar', 'gz', 'bz', 'bzip', 'xz', 'rar', '7z'],
    name: 'file-archive-o',
  },
  { extensions: ['mp3', 'wma', 'ogg', 'oga', 'wav', 'flac', 'aac'], name: 'file-audio-o' },
  {
    extensions: [
      'mp4',
      'm4p',
      'm4v',
      'mpg',
      'mp2',
      'mpeg',
      'mpe',
      'mpv',
      'm2v',
      'avi',
      'mkv',
      'flv',
      'ogv',
      'mov',
      '3gp',
      '3g2',
    ],
    name: 'file-video-o',
  },
  { extensions: ['doc', 'dot', 'docx', 'docm', 'dotx', 'dotm', 'docb'], name: 'file-word-o' },
  {
    extensions: [
      'xls',
      'xlt',
      'xlm',
      'xlsx',
      'xlsm',
      'xltx',
      'xltm',
      'xlsb',
      'xla',
      'xlam',
      'xll',
      'xlw',
    ],
    name: 'file-excel-o',
  },
  {
    extensions: [
      'ppt',
      'pot',
      'pps',
      'pptx',
      'pptm',
      'potx',
      'potm',
      'ppam',
      'ppsx',
      'ppsm',
      'sldx',
      'sldm',
    ],
    name: 'file-powerpoint-o',
  },
];

// eslint-disable-next-line import/prefer-default-export
export const getIconName = (type, path) => {
  if (entryTypeIcons[type]) return entryTypeIcons[type];

  const extension = path.split('.').pop();
  const file = fileTypeIcons.find(t => t.extensions.some(ext => ext === extension));

  return file ? file.name : 'file-text-o';
};
