import submitContentChanges from '../../services/submit_content_changes';
import savedContentMetaQuery from '../queries/saved_content_meta.query.graphql';

const submitContentChangesResolver = (
  _,
  { input: { project: projectId, username, sourcePath, content, images } },
  { cache },
) => {
  return submitContentChanges({ projectId, username, sourcePath, content, images }).then(
    savedContentMeta => {
      cache.writeQuery({
        query: savedContentMetaQuery,
        data: {
          savedContentMeta: {
            __typename: 'SavedContentMeta',
            ...savedContentMeta,
          },
        },
      });
    },
  );
};

export default submitContentChangesResolver;
