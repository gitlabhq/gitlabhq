import Api from '~/api';

const extractTitle = content => {
  const matches = content.match(/title: (.+)\n/i);

  return matches ? Array.from(matches)[1] : '';
};

const loadSourceContent = ({ projectId, sourcePath }) =>
  Api.getRawFile(projectId, sourcePath).then(({ data }) => ({
    title: extractTitle(data),
    content: data,
  }));

export default loadSourceContent;
