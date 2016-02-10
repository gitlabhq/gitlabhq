class Projects::PagesController < Projects::ApplicationController
  layout 'project_settings'

  before_action :authorize_update_pages!, except: [:show]
  before_action :authorize_remove_pages!, only: :destroy

  helper_method :valid_certificate?, :valid_certificate_key?
  helper_method :valid_key_for_certificiate?, :valid_certificate_intermediates?
  helper_method :certificate, :certificate_key

  def show
  end

  def update
    if @project.update_attributes(pages_params)
      redirect_to namespace_project_pages_path(@project.namespace, @project)
    else
      render 'show'
    end
  end

  def certificate
    @project.remove_pages_certificate
  end

  def destroy
    @project.remove_pages

    respond_to do |format|
      format.html { redirect_to project_path(@project) }
    end
  end

  private

  def pages_params
    params.require(:project).permit(
                              :pages_custom_certificate,
                              :pages_custom_certificate_key,
                              :pages_custom_domain,
                              :pages_redirect_http,
    )
  end

  def valid_certificate?
    certificate.present?
  end

  def valid_certificate_key?
    certificate_key.present?
  end

  def valid_key_for_certificiate?
    return false unless certificate
    return false unless certificate_key

    # We compare the public key stored in certificate with public key from certificate key
    certificate.public_key.to_pem == certificate_key.public_key.to_pem
  rescue OpenSSL::X509::CertificateError, OpenSSL::PKey::PKeyError
    false
  end

  def valid_certificate_intermediates?
    return false unless certificate

    store = OpenSSL::X509::Store.new
    store.set_default_paths

    # This forces to load all intermediate certificates stored in `pages_custom_certificate`
    Tempfile.open('project_certificate') do |f|
      f.write(@project.pages_custom_certificate)
      f.flush
      store.add_file(f.path)
    end

    store.verify(certificate)
  rescue OpenSSL::X509::StoreError
    false
  end

  def certificate
    return unless @project.pages_custom_certificate

    @certificate ||= OpenSSL::X509::Certificate.new(@project.pages_custom_certificate)
  rescue OpenSSL::X509::CertificateError
    nil
  end

  def certificate_key
    return unless @project.pages_custom_certificate_key
    @certificate_key ||= OpenSSL::PKey::RSA.new(@project.pages_custom_certificate_key)
  rescue OpenSSL::PKey::PKeyError, OpenSSL::Cipher::CipherError
    nil
  end
end
