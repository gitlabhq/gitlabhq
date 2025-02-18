import { mapState } from 'pinia';
import { useBatchComments } from '~/batch_comments/store';
import { IMAGE_DIFF_POSITION_TYPE } from '../constants';

export default {
  computed: {
    ...mapState(useBatchComments, [
      'shouldRenderDraftRow',
      'shouldRenderParallelDraftRow',
      'draftsForLine',
      'draftsForFile',
      'hasParallelDraftLeft',
      'hasParallelDraftRight',
    ]),
    imageDiscussionsWithDrafts() {
      return this.diffFile.discussions
        .filter((f) => f.position?.position_type === IMAGE_DIFF_POSITION_TYPE)
        .concat(this.draftsForFile(this.diffFile.file_hash));
    },
  },
};
