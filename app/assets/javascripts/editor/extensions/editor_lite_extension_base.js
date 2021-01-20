import { ERROR_INSTANCE_REQUIRED_FOR_EXTENSION } from '../constants';

export class EditorLiteExtension {
  constructor({ instance, ...options } = {}) {
    if (instance) {
      Object.assign(instance, options);
    } else if (Object.entries(options).length) {
      throw new Error(ERROR_INSTANCE_REQUIRED_FOR_EXTENSION);
    }
  }
}
