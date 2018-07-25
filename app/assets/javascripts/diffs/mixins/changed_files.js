export default {
  props: {
    diffFiles: {
      type: Array,
      required: true,
    },
  },
  methods: {
    fileChangedIcon(diffFile) {
      if (diffFile.deletedFile) {
        return 'file-deletion';
      } else if (diffFile.newFile) {
        return 'file-addition';
      }
      return 'file-modified';
    },
    fileChangedClass(diffFile) {
      if (diffFile.deletedFile) {
        return 'cred';
      } else if (diffFile.newFile) {
        return 'cgreen';
      }

      return '';
    },
    truncatedDiffPath(path) {
      const maxLength = 60;

      if (path.length > maxLength) {
        const start = path.length - maxLength;
        const end = start + maxLength;
        return `...${path.slice(start, end)}`;
      }

      return path;
    },
  },
};
