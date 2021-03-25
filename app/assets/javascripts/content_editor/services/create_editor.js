import { Editor } from 'tiptap';
import { Bold, Code } from 'tiptap-extensions';

const createEditor = ({ content } = {}) => {
  return new Editor({
    extensions: [new Bold(), new Code()],
    content,
  });
};

export default createEditor;
