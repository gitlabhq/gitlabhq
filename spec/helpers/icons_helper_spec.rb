require 'spec_helper'

describe IconsHelper do
  describe 'file_type_icon_class' do
    it 'returns folder class' do
      expect(file_type_icon_class('folder', 0, 'folder_name')).to eq 'folder'
    end

    it 'returns share class' do
      expect(file_type_icon_class('file', '120000', 'link')).to eq 'share'
    end

    it 'returns file-pdf-o class with .pdf' do
      expect(file_type_icon_class('file', 0, 'filename.pdf')).to eq 'file-pdf-o'
    end

    it 'returns file-image-o class with .jpg' do
      expect(file_type_icon_class('file', 0, 'filename.jpg')).to eq 'file-image-o'
    end

    it 'returns file-image-o class with .JPG' do
      expect(file_type_icon_class('file', 0, 'filename.JPG')).to eq 'file-image-o'
    end

    it 'returns file-image-o class with .png' do
      expect(file_type_icon_class('file', 0, 'filename.png')).to eq 'file-image-o'
    end

    it 'returns file-archive-o class with .tar' do
      expect(file_type_icon_class('file', 0, 'filename.tar')).to eq 'file-archive-o'
    end

    it 'returns file-archive-o class with .TAR' do
      expect(file_type_icon_class('file', 0, 'filename.TAR')).to eq 'file-archive-o'
    end

    it 'returns file-archive-o class with .tar.gz' do
      expect(file_type_icon_class('file', 0, 'filename.tar.gz')).to eq 'file-archive-o'
    end

    it 'returns file-audio-o class with .mp3' do
      expect(file_type_icon_class('file', 0, 'filename.mp3')).to eq 'file-audio-o'
    end

    it 'returns file-audio-o class with .MP3' do
      expect(file_type_icon_class('file', 0, 'filename.MP3')).to eq 'file-audio-o'
    end

    it 'returns file-audio-o class with .wav' do
      expect(file_type_icon_class('file', 0, 'filename.wav')).to eq 'file-audio-o'
    end

    it 'returns file-video-o class with .avi' do
      expect(file_type_icon_class('file', 0, 'filename.avi')).to eq 'file-video-o'
    end

    it 'returns file-video-o class with .AVI' do
      expect(file_type_icon_class('file', 0, 'filename.AVI')).to eq 'file-video-o'
    end

    it 'returns file-video-o class with .mp4' do
      expect(file_type_icon_class('file', 0, 'filename.mp4')).to eq 'file-video-o'
    end

    it 'returns file-word-o class with .doc' do
      expect(file_type_icon_class('file', 0, 'filename.doc')).to eq 'file-word-o'
    end

    it 'returns file-word-o class with .DOC' do
      expect(file_type_icon_class('file', 0, 'filename.DOC')).to eq 'file-word-o'
    end

    it 'returns file-word-o class with .docx' do
      expect(file_type_icon_class('file', 0, 'filename.docx')).to eq 'file-word-o'
    end

    it 'returns file-excel-o class with .xls' do
      expect(file_type_icon_class('file', 0, 'filename.xls')).to eq 'file-excel-o'
    end

    it 'returns file-excel-o class with .XLS' do
      expect(file_type_icon_class('file', 0, 'filename.XLS')).to eq 'file-excel-o'
    end

    it 'returns file-excel-o class with .xlsx' do
      expect(file_type_icon_class('file', 0, 'filename.xlsx')).to eq 'file-excel-o'
    end

    it 'returns file-excel-o class with .ppt' do
      expect(file_type_icon_class('file', 0, 'filename.ppt')).to eq 'file-powerpoint-o'
    end

    it 'returns file-excel-o class with .PPT' do
      expect(file_type_icon_class('file', 0, 'filename.PPT')).to eq 'file-powerpoint-o'
    end

    it 'returns file-excel-o class with .pptx' do
      expect(file_type_icon_class('file', 0, 'filename.pptx')).to eq 'file-powerpoint-o'
    end

    it 'returns file-text-o class with .unknow' do
      expect(file_type_icon_class('file', 0, 'filename.unknow')).to eq 'file-text-o'
    end

    it 'returns file-text-o class with no extension' do
      expect(file_type_icon_class('file', 0, 'CHANGELOG')).to eq 'file-text-o'
    end
  end
end
