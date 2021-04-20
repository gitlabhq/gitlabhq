import { s__ } from '~/locale';

export const MSG_CANNOT_PUSH_CODE_SHOULD_FORK = s__(
  'WebIDE|You need permission to edit files directly in this project. Fork this project to make your changes and submit a merge request.',
);

export const MSG_CANNOT_PUSH_CODE_GO_TO_FORK = s__(
  'WebIDE|You need permission to edit files directly in this project. Go to your fork to make changes and submit a merge request.',
);

export const MSG_CANNOT_PUSH_CODE = s__(
  'WebIDE|You need permission to edit files directly in this project.',
);

export const MSG_CANNOT_PUSH_UNSIGNED = s__(
  'WebIDE|This project does not accept unsigned commits. You will not be able to commit your changes through the Web IDE.',
);

export const MSG_CANNOT_PUSH_UNSIGNED_SHORT = s__(
  'WebIDE|This project does not accept unsigned commits.',
);

export const MSG_FORK = s__('WebIDE|Fork project');

export const MSG_GO_TO_FORK = s__('WebIDE|Go to fork');
