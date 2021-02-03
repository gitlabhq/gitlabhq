# frozen_string_literal: true

Sprockets.register_compressor 'application/javascript', :terser, Terser::Compressor
