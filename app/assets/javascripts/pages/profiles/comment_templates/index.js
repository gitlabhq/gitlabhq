import { initCommentTemplates } from '~/comment_templates';
import fetchAllQuery from './queries/saved_replies.query.graphql';
import fetchSingleQuery from './queries/get_saved_reply.query.graphql';
import createMutation from './queries/create_saved_reply.mutation.graphql';
import deleteMutation from './queries/delete_saved_reply.mutation.graphql';
import updateMutation from './queries/update_saved_reply.mutation.graphql';

initCommentTemplates({
  fetchAllQuery,
  fetchSingleQuery,
  createMutation,
  deleteMutation,
  updateMutation,
});
