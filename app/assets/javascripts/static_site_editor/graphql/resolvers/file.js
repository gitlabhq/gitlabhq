import loadSourceContent from '../../services/load_source_content';

const fileResolver = ({ fullPath: projectId }, { path: sourcePath }) => {
  return loadSourceContent({ projectId, sourcePath }).then(sourceContent => ({
    // eslint-disable-next-line @gitlab/require-i18n-strings
    __typename: 'File',
    ...sourceContent,
  }));
};

export default fileResolver;
